WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), 
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
), 
TopProducts AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.p_retailprice,
        pd.total_supply_value,
        ROW_NUMBER() OVER (ORDER BY pd.total_supply_value DESC) AS product_rank
    FROM 
        ProductDetails pd
    WHERE 
        pd.total_supply_value > (SELECT AVG(total_supply_value) FROM ProductDetails)
)

SELECT 
    c.c_custkey,
    c.c_name,
    n.n_name AS nation,
    o.o_orderkey,
    o.o_orderdate,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    l.l_shipmode,
    COALESCE(tr.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01'
    GROUP BY 
        l.l_orderkey
) tr ON o.o_orderkey = tr.l_orderkey
JOIN 
    RankedSuppliers rs ON c.c_nationkey = rs.s_nationkey
WHERE 
    rs.rn <= 3 AND
    EXISTS (
        SELECT 1 
        FROM TopProducts tp 
        WHERE tp.p_partkey = l.l_partkey AND tp.product_rank <= 10
    )
ORDER BY 
    total_revenue DESC, 
    o.o_orderdate ASC;