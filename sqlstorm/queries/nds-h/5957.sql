
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND o.o_totalprice > 5000
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    r.s_name AS supplier_name,
    n.n_name AS nation_name,
    o.o_orderkey AS order_key,
    o.o_totalprice AS order_total,
    o.o_orderdate AS order_date,
    o.line_item_count,
    DENSE_RANK() OVER (PARTITION BY r.s_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
FROM 
    RankedSuppliers r 
JOIN 
    HighValueOrders o ON r.rnk <= 5 
JOIN 
    nation n ON r.s_nationkey = n.n_nationkey
ORDER BY 
    n.n_name, r.s_name, o.o_orderkey;
