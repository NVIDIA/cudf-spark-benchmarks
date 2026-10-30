
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), 
HighSpendCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(o.total_spent, 0) AS total_spent,
        COALESCE(o.order_count, 0) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders o ON c.c_custkey = o.c_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(s.s_acctbal) FROM supplier s)
)

SELECT 
    r.r_name,
    SUM(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_supplycost ELSE 0 END) AS total_supply_cost,
    COUNT(DISTINCT h.c_custkey) AS high_spenders_count,
    MAX(h.total_spent) AS highest_spent
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    HighSpendCustomers h ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE 
    r.r_name IN ('AMERICA', 'EUROPE')
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT h.c_custkey) > 0
ORDER BY 
    total_supply_cost DESC;
