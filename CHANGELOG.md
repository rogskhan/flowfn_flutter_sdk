# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-01

### Added
- Initial release of FlowFn SDK
- API client with app and user authentication support
- Workflow service for triggering workflows and awaiting results
- Auth service for user authentication (login, signup, OTP)
- Models for User, WorkflowRun, and AuthResponse
- Polling mechanism with 2-minute timeout for workflow results
- Support for all HTTP methods (GET, POST, PUT, PATCH) for workflow triggers

