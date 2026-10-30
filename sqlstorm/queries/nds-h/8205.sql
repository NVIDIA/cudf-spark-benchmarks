WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        c.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.order_rank <= 10
)
SELECT 
    t.o_orderkey,
    t.o_totalprice,
    t.o_orderstatus,
    t.o_orderdate,
    t.c_name,
    t.nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(l.l_orderkey) AS item_count
FROM 
    TopOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
GROUP BY 
    t.o_orderkey, t.o_totalprice, t.o_orderstatus, t.o_orderdate, t.c_name, t.nation_name
ORDER BY 
    total_sales DESC, t.o_orderdate;