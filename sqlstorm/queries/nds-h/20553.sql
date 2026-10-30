
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
),
LowInventoryParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size
    FROM 
        part p
    WHERE 
        p.p_size < (SELECT AVG(p_size) FROM part)
)
SELECT DISTINCT 
    hvc.c_name AS customer_name,
    rs.s_name AS supplier_name,
    lip.p_name AS part_name,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        WHEN l.l_returnflag IS NULL THEN 'Not Returned'
        ELSE 'Unknown'
    END AS return_status,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = o.o_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rnk <= 5
JOIN 
    LowInventoryParts lip ON l.l_partkey = lip.p_partkey
GROUP BY 
    hvc.c_name, rs.s_name, lip.p_name, return_status
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l_extendedprice) FROM lineitem WHERE l_returnflag = 'A')
ORDER BY 
    total_revenue DESC;
