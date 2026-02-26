# ModbusAppControler
Для переноса логики нужно:
Скопировать папки logic/ и data/ в новый проект.
Добавить import "logic" в main.qml.
Создать экземпляр: AppController { id: controller }.
Использовать controller.* в своём UI.
