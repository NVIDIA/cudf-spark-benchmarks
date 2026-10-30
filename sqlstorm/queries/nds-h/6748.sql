WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.customer_name,
        r.nation_name,
        r.o_totalprice
    FROM RankedOrders r
    WHERE r.total_price_rank <= 10
),
PartDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_orderkey IN (SELECT o_orderkey FROM TopOrders)
    GROUP BY l.l_orderkey, l.l_partkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(SUM(pd.total_quantity), 0) AS quantity_sold,
    COALESCE(SUM(pd.total_sales), 0) AS total_sales_amount
FROM part p
LEFT JOIN PartDetails pd ON p.p_partkey = pd.l_partkey
GROUP BY p.p_partkey, p.p_name, p.p_brand
ORDER BY total_sales_amount DESC, quantity_sold DESC
LIMIT 10;