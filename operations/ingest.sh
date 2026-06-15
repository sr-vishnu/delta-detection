#!/bin/bash

#create the tables
python -m src.scripts.create

# The batches are intentionally interleaved to simulate the scenario described in the assignment.
# Based on my assumption that loading and processing are independent steps, I have also interleaved the processing commands within the load sequence.
# This sequence is not meant to be the only valid execution order. You can experiment with different mutated sequences, run the validation after each one, and observe how the results change while still respecting the defined constraints.

python -m src.scripts.load raw_membership 20260101
sleep 1
python -m src.scripts.load raw_customer_profile 20260101
sleep 1
python -m src.scripts.load raw_customer_profile 20260102
sleep 1
python -m src.scripts.load raw_customer_profile 20260103
sleep 1
python -m src.scripts.load raw_customer_profile 20260104
sleep 1
python -m src.scripts.load raw_customer_profile 20260105
sleep 1

python -m src.scripts.process customer_profile
sleep 1
python -m src.scripts.process membership
sleep 1

python -m src.scripts.load raw_membership 20260102
sleep 1
python -m src.scripts.load raw_membership 20260103
sleep 1
python -m src.scripts.load raw_membership 20260104
sleep 1
python -m src.scripts.load raw_membership 20260105
sleep 1
python -m src.scripts.load raw_membership 20260106
sleep 1
python -m src.scripts.load raw_customer_profile 20260106
sleep 1

python -m src.scripts.process customer_profile
sleep 1
python -m src.scripts.process membership
sleep 1

python -m src.scripts.load raw_customer_profile 20260107
sleep 1
python -m src.scripts.load raw_customer_profile 20260108
sleep 1
python -m src.scripts.load raw_membership 20260107
sleep 1
python -m src.scripts.load raw_membership 20260108
sleep 1
python -m src.scripts.load raw_membership 20260109
sleep 1

python -m src.scripts.process customer_profile
sleep 1
python -m src.scripts.process membership
sleep 1

python -m src.scripts.load raw_membership 20260110
sleep 1
python -m src.scripts.load raw_customer_profile 20260109
sleep 1
python -m src.scripts.load raw_customer_profile 20260110

python -m src.scripts.process customer_profile
sleep 1
python -m src.scripts.process membership
sleep 1
