# Thinkigen ERD Contract

This file defines the logical relationships that the physical schema must preserve.

## Core hierarchy

Organization database
→ School
→ Branch
→ Academic Year
→ Class
→ Section
→ Student

## Academic configuration

School
→ Academic Year
→ Branch
→ Class
→ Section

Class
→ ClassSubject
→ Subject

School
→ SchoolSubject
→ Subject

## Identity

User
→ approved domain identity such as Student / Teacher

The exact physical FK paths must be implemented from the finalized entity definitions and must not be guessed by Cursor.

## Historical rule

Historical academic placement must retain enough foreign-key context to distinguish:
- school
- academic year
- branch
- class
- section
- student

Current placement must not overwrite historical facts.
