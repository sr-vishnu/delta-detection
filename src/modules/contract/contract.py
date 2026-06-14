from datetime import date, datetime
from typing import Literal, Optional, List
from pydantic import BaseModel, EmailStr, field_validator, model_validator
import re


HIRAGANA_RE = re.compile(r"^[ぁ-ゖー]+$")
E164_COUNTRY_CODE_RE = re.compile(r"^\+\d{1,3}$")


class ETLMetadata(BaseModel):
    source_system: str
    source_file: str
    processed_at: datetime


class Email(BaseModel):
    is_primary: bool
    email: EmailStr


class Phone(BaseModel):
    is_primary: bool
    category: Literal["home", "mobile"]
    country_code: str
    phone_number: str

    @field_validator("country_code")
    @classmethod
    def validate_country_code(cls, v: str) -> str:
        if not E164_COUNTRY_CODE_RE.match(v):
            raise ValueError("country_code must be in E.164 style, e.g. +81, +886, +86")
        return v


class Address(BaseModel):
    id: Optional[int] = None
    is_primary: bool
    postal_code: Optional[str] = None
    prefecture_or_state: Optional[str] = None
    city: Optional[str] = None
    street_address: Optional[str] = None
    building_name_and_number: Optional[str] = None
    full_address: Optional[str] = None


class EmbeddedMembership(BaseModel):
    source_type: str
    source_id: str
    program_id: int
    program_name: str
    membership_id: str
    rank_name: str
    created_at: datetime
    status: Literal["active", "inactive"]
    etl_metadata: ETLMetadata

    @field_validator(
        "source_type",
        "source_id",
        "program_name",
        "membership_id",
        "rank_name",
    )
    @classmethod
    def required_non_empty(cls, v: str) -> str:
        if v is None or not str(v).strip():
            raise ValueError("field is required and cannot be empty")
        return v


class CustomerProfile(BaseModel):
    source_type: str
    source_id: str
    guest_type: Literal["member", "non_member"]

    last_name: str
    first_name: str
    last_name_kana: Optional[str] = None
    first_name_kana: Optional[str] = None
    birthday: Optional[date] = None

    emails: Optional[List[Email]] = None
    phones: Optional[List[Phone]] = None
    addresses: Optional[List[Address]] = None
    tags: Optional[List[str]] = None
    created_at: Optional[datetime] = None
    etl_metadata: ETLMetadata

    memberships: Optional[List[EmbeddedMembership]] = None

    @field_validator("source_type", "source_id", "last_name", "first_name")
    @classmethod
    def required_non_empty(cls, v: str) -> str:
        if v is None or not str(v).strip():
            raise ValueError("field is required and cannot be empty")
        return v

    @field_validator("last_name_kana", "first_name_kana")
    @classmethod
    def validate_hiragana(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and not HIRAGANA_RE.match(v):
            raise ValueError("kana fields must contain full-width hiragana only")
        return v

    @model_validator(mode="after")
    def validate_member_has_membership(self):
        if self.guest_type == "member" and not self.memberships:
            raise ValueError("guest_type='member' requires at least one membership")
        return self

    @model_validator(mode="after")
    def validate_duplicate_emails_inside_record(self):
        if self.emails:
            emails = [str(e.email).lower() for e in self.emails]
            if len(emails) != len(set(emails)):
                raise ValueError("duplicate emails inside the same customer record are not allowed")
        return self
