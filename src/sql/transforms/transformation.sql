WITH transformed_data AS (
    SELECT
        cp.source_type,
        cp.source_id,
        cp.customer_profile.guest_type,
        cp.customer_profile.last_name,
        cp.customer_profile.first_name,
        cp.customer_profile.last_name_kana,
        cp.customer_profile.first_name_kana,
        cp.customer_profile.birthday,
        cp.customer_profile.emails,
        cp.customer_profile.phones,
        cp.customer_profile.addresses,
        cp.customer_profile.tags,
        cp.customer_profile.created_at,
        cp.metadata AS etl_metadata,
        COALESCE(m.memberships, []) AS memberships
    FROM customer_profile cp
    LEFT JOIN (
        SELECT
            ms.source_type,
            ms.source_id,
            LIST({
                'source_type': ms.source_type,
                'source_id': ms.source_id,
                'program_id': ms.program_id,
                'program_name': ms.membership.program_name,
                'membership_id': ms.membership_id,
                'rank_name': LOWER(ms.membership.rank_name),
                'created_at': ms.membership.created_at,
                'status': ms.membership.status,
                'etl_metadata': ms.metadata
            }) AS memberships
        FROM membership ms
        WHERE ms.status = 'CURRENT'
        GROUP BY 1, 2
    ) m ON cp.source_type = m.source_type AND cp.source_id = m.source_id
    WHERE cp.status = 'CURRENT'
)
SELECT to_json(td) AS payload
FROM transformed_data td;
