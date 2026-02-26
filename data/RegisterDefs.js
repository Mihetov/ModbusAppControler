.pragma library

var REGISTERS = {
    info: [
        {name:"HREG_deviceID",  hex:"0xF001", rwe:"R",  fmt:"Byte",    count:1,  desc:"Идентификатор устройства"},
        {name:"HREG_srelease",  hex:"0xF008", rwe:"R",  fmt:"Char[16]",count:8,  desc:"Дата создания"},
        {name:"HREG_sfirmwar",  hex:"0xF010", rwe:"R",  fmt:"Char[32]",count:16, desc:"Прошивка"},
        {name:"HREG_serialn",   hex:"0xF024", rwe:"R",  fmt:"Uint32",  count:2,  desc:"Серийный номер"}
    ],
    system: [
        {name:"HREG_slaveID",   hex:"0xF000", rwe:"RWE",fmt:"Byte",    count:1,  min:1, max:247, desc:"Сетевой адрес"},
        {name:"HREG_baudidx",   hex:"0xF021", rwe:"RWE",fmt:"Byte",    count:1,  list:[
            {v:0,t:"9600"},{v:1,t:"19200"},{v:2,t:"38400"},{v:3,t:"57600"},{v:4,t:"115200"}
        ], desc:"Скорость обмена"}
    ],
    mode: [
        {name:"HREG_Range",     hex:"0xC80C", rwe:"RWE",fmt:"Byte",    count:1,  list:[
            {v:0,t:"Ток"},{v:1,t:"Напряжение"}
        ], desc:"Режим измерения"},
        {name:"HREG_FiltrIIR",  hex:"0xC80D", rwe:"RWE",fmt:"Float32", count:2,  min:1, max:100, desc:"Коэфф. фильтра"}
    ],
    scaling: [
        {name:"HREG_ApproxA1",  hex:"0xC810", rwe:"RWE",fmt:"Float32", count:2, desc:"Точка 1, вход"},
        {name:"HREG_ApproxV1",  hex:"0xC812", rwe:"RWE",fmt:"Float32", count:2, desc:"Точка 1, выход"},
        {name:"HREG_ApproxA2",  hex:"0xC814", rwe:"RWE",fmt:"Float32", count:2, desc:"Точка 2, вход"},
        {name:"HREG_ApproxV2",  hex:"0xC816", rwe:"RWE",fmt:"Float32", count:2, desc:"Точка 2, выход"}
    ],
    measurement: [
        {name:"HREG_Value",     hex:"0xC800", rwe:"R",  fmt:"Float32", count:2, desc:"Масштабированное значение"},
        {name:"HREG_TermC",     hex:"0xE100", rwe:"R",  fmt:"Float32", count:2, desc:"Температура °C"},
        {name:"HREG_Vcc3v3",    hex:"0xE102", rwe:"R",  fmt:"Float32", count:2, desc:"Напряжение питания"}
    ]
};
