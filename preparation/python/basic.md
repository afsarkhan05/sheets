# Basic

## Python

module vs package (module just one python class where as package is `__init__` with multi py files)  
PIP --> Python Installer Package - Way to install py package  
Interpreter, Compiler language, easy to learn, community support, 3rd party lib support, AI support, lightweight  
List[] & Set -> utable  
Tuple() (Immutable object)  
global (global variable  
`_var` (protected)  
`__var` (private and not available outside of class

- steeaming using generator
- generator gives lazy loading of data using yield
- pandas has in-build feature to load data files in chunks internally using yield only
- db instead of full data in memory - use cursor and buffering to avoid full network traffic, memory etc
- stream data to avoid memory over utilization
- streaming generator to stream data as an when needed
- Memory optimization on large file where streaming not possible due to calculation req
- dtypes - change if ids can fit as int32, int16 from default int64 in pandas
- try to partition the file (1gb instead of 20 gb) as parquet which is binary
- parquet file partition can also help read specific column - reduce network traffic, memory etc
- structure files like (e.g., date=2026-09/). If your calculation only cares about a specific month
- chunking + parallelism - use distributed parallalism for large data like pyspark or dask
- stream generator not possible - other option
- downsize integer/float to smallest safest like int64 to int32 etc
- partition - parquet - binary - partition pruning by selective column - folder by dates
- Dask/PySpark
- `data = (x * 2 for x in range(10_000_000))` (lazy generator loading)
- `data = tuple(x * 2 for x in range(10_000_000))` (tuple creation)
- `[...]` → list comprehension → eager
- `(...)` → generator expression → lazy
- `tuple(...)` → materializes tuple → eager
