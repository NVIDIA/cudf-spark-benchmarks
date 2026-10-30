WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
FilteredCustomer AS (
    SELECT
        c.c_custkey,
        c.c_name,
        n.n_name AS customer_nation,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS rn
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal IS NOT NULL
)
SELECT 
    fs.s_suppkey,
    fs.s_name,
    fs.total_supply_value,
    fs.total_parts_supplied,
    os.total_order_value,
    os.total_line_items,
    fc.c_custkey,
    fc.c_name,
    fc.customer_nation,
    fc.c_acctbal
FROM 
    SupplierStats fs
LEFT JOIN 
    OrderStats os ON fs.s_suppkey = os.o_custkey
JOIN 
    FilteredCustomer fc ON os.o_custkey = fc.c_custkey
WHERE 
    fs.total_supply_value > 100000
    AND fc.rn <= 5
ORDER BY 
    fs.total_supply_value DESC, fc.c_acctbal DESC;
