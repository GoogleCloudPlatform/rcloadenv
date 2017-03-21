google-cloud-runtimeconfig-loadenv
----------------------------------

This package distributes a binary called ``rcloadenv``, which reads a
configuration from the `Google Cloud Runtime Configuration API
<https://cloud.google.com/deployment-manager/runtime-configurator/reference/rest/>`_
and launches an executable with the loaded environment.

Use it from a shell like

.. code-block:: bash

    rcloadenv my-config -- my-binary-that-uses-the-env-vars

