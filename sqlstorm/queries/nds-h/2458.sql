
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        p.p_size
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customer_count,
    AVG(s.s_acctbal) AS average_supplier_acctbal,
    SUM(CASE 
            WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_discounted_sales,
    MAX(o.o_totalprice) AS max_order_value
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierPartDetails spd ON s.s_suppkey = spd.ps_suppkey
LEFT JOIN 
    lineitem l ON spd.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers hvc ON o.o_custkey = hvc.c_custkey
WHERE 
    n.n_name IS NOT NULL 
    AND n.n_nationkey IN (SELECT DISTINCT hvc.c_custkey FROM HighValueCustomers hvc)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT hvc.c_custkey) > 0
ORDER BY 
    nation;
