# Refactor: Replace Global Singletons with Dependency Injection

## Source

Synthetic task based on a widespread anti-pattern: services reaching for module-level singleton instances instead of receiving their collaborators through their constructors.

## Problem

`UserService` and `OrderService` import and use module-level singleton instances (`logger`, `cache`, `mailer`) directly. This tight coupling makes the services impossible to test in true isolation, prevents running multiple independent service instances, and creates hidden dependencies that are not visible from the class interface. The services should instead receive their dependencies through constructor parameters.

## Acceptance Criteria

- `UserService.__init__` accepts `logger` and `cache` as constructor parameters and stores them as instance attributes
- `OrderService.__init__` accepts `logger`, `cache`, and `mailer` as constructor parameters and stores them as instance attributes
- Service methods use `self.logger`, `self.cache`, and `self.mailer` instead of module-level globals
- `user_service.py` does not import the global `logger` instance from `services.logger`
- `user_service.py` does not import the global `cache` instance from `services.cache`
- `order_service.py` does not import the global `logger` instance from `services.logger`
- `order_service.py` does not import the global `cache` instance from `services.cache`
- `order_service.py` does not import the global `mailer` instance from `services.mailer`
- The `Logger`, `Cache`, and `Mailer` classes still exist in their respective modules
- Constructing `UserService()` or `OrderService()` without arguments raises `TypeError`
- Tests are updated to create fresh dependency instances and inject them into the services
- The test fixture in `conftest.py` is updated accordingly
- All existing test assertions remain identical and pass

## Constraints

- Do not rename any class or method
- Do not change the behavior of any service method
- Do not remove the `Logger`, `Cache`, or `Mailer` classes from their modules
- The global singleton instances (`logger`, `cache`, `mailer`) may remain in their own modules but must not be imported by service modules
