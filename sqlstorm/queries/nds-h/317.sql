
WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name AS customer_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    o.o_orderkey AS order_id,
    hv.total_price,
    r.r_name AS region_name
FROM 
    HighValueOrders hv
JOIN 
    orders o ON hv.o_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSupplier s ON s.rn = 1
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey 
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (c.c_acctbal IS NULL OR c.c_acctbal >= 5000) 
    AND o.o_orderkey NOT IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_returnflag = 'R')
ORDER BY 
    hv.total_price DESC, 
    c.c_name ASC;
