WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrderDetails AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate,
        ro.o_orderpriority,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_extended_price,
        SUM(l.l_discount) AS total_discounted_price
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ro.order_rank <= 5
    GROUP BY 
        ro.o_orderkey, ro.o_totalprice, ro.o_orderdate, ro.o_orderpriority, p.p_name
)
SELECT 
    tod.o_orderkey,
    tod.o_totalprice,
    tod.o_orderdate,
    tod.o_orderpriority,
    COUNT(DISTINCT tod.p_name) AS distinct_parts,
    SUM(tod.total_quantity) AS total_quantity,
    SUM(tod.total_extended_price) AS total_extended_price,
    SUM(tod.total_discounted_price) AS total_discounted_price
FROM 
    TopOrderDetails tod
GROUP BY 
    tod.o_orderkey, tod.o_totalprice, tod.o_orderdate, tod.o_orderpriority
ORDER BY 
    tod.o_totalprice DESC
LIMIT 10;
