
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate <= '1997-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
        LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    p.p_size,
    ps.ps_availqty,
    s.s_name,
    r.r_name,
    COALESCE(c.order_count, 0) AS total_orders,
    o.o_orderkey AS latest_order,
    CAST(o.o_orderdate AS DATE) AS order_date,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY p.p_retailprice DESC) AS retail_rank
FROM 
    part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN CustomerOrderCounts c ON s.s_suppkey = c.c_custkey
    LEFT JOIN RankedOrders o ON o.o_orderkey = (
        SELECT MAX(o2.o_orderkey)
        FROM orders o2
        WHERE o2.o_orderdate < (DATE '1998-10-01' - INTERVAL '30 days')
        AND o2.o_orderstatus <> 'O'
    )
WHERE 
    (p.p_size BETWEEN 10 AND 20 OR p.p_name LIKE '%widget%')
    AND (ps.ps_availqty IS NOT NULL AND ps.ps_availqty > 0)
    AND s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = n.n_nationkey
    )
ORDER BY 
    r.r_name, p.p_retailprice DESC
LIMIT 100;
