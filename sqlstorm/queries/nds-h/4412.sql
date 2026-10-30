WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rn
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000.00
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    SUM(od.total_order_value) AS total_value,
    COUNT(od.o_orderkey) AS order_count,
    AVG(cl.c_acctbal) AS average_customer_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    OrderDetails od ON p.p_partkey = od.o_orderkey
LEFT JOIN 
    HighValueCustomers cl ON cl.c_custkey = od.o_orderkey
WHERE 
    (p.p_size > 20 OR p.p_type LIKE '%elastic%') AND
    (s.s_acctbal IS NULL OR s.s_acctbal > 500.00)
GROUP BY 
    r.r_name
HAVING 
    SUM(od.total_order_value) > 10000.00
ORDER BY 
    total_value DESC;
