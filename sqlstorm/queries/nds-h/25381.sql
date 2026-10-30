WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), 
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
string_benchmark AS (
    SELECT 
        s.s_name AS supplier_name,
        cs.c_name AS customer_name,
        CONCAT(s.s_name, ' | ', cs.c_name) AS combined_name,
        LENGTH(CONCAT(s.s_name, ' | ', cs.c_name)) AS combined_length,
        total_supply_cost,
        total_spent
    FROM 
        supplier_summary s
    JOIN 
        customer_order_summary cs ON s.part_count > 5 AND s.total_supply_cost > 1000 AND cs.order_count > 3
)
SELECT 
    supplier_name,
    customer_name,
    combined_name,
    combined_length,
    total_supply_cost,
    total_spent
FROM 
    string_benchmark
ORDER BY 
    combined_length DESC
LIMIT 10;
