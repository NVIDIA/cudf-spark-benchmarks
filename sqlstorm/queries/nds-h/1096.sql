
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
), 

OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS number_of_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)

SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
    COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost,
    AVG(od.total_price) AS avg_order_price
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = ps.ps_partkey
WHERE 
    p.p_retailprice BETWEEN 50 AND 200
AND 
    (rs.rank IS NULL OR rs.rank <= 5)
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COALESCE(SUM(ps.ps_availqty), 0) > 0 
ORDER BY 
    avg_order_price DESC;
