
WITH CustomerOrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        c.c_nationkey,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        c.c_name, c.c_nationkey, o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        cod.customer_name,
        cod.c_nationkey,
        cod.o_orderkey,
        cod.o_orderdate,
        cod.total_price,
        cod.item_count,
        DENSE_RANK() OVER (PARTITION BY cod.c_nationkey ORDER BY cod.total_price DESC) AS price_rank
    FROM 
        CustomerOrderDetails cod
)
SELECT 
    ro.customer_name,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_price,
    ro.item_count,
    ro.price_rank,
    n.n_name AS nation_name,
    p.p_name AS popular_part_name
FROM 
    RankedOrders ro
JOIN 
    nation n ON ro.c_nationkey = n.n_nationkey
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    ro.price_rank = 1
ORDER BY 
    ro.total_price DESC;
