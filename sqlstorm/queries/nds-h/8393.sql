WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    GROUP BY s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
FinalReport AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        ps.avg_acctbal,
        co.order_count,
        co.total_spent,
        rp.p_name AS top_product,
        rp.p_retailprice
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN SupplierStats ps ON n.n_nationkey = ps.s_nationkey
    JOIN CustomerOrders co ON n.n_nationkey = co.c_nationkey
    JOIN RankedProducts rp ON n.n_nationkey = rp.p_partkey
    WHERE rp.price_rank = 1
    ORDER BY region, nation
)
SELECT *
FROM FinalReport
WHERE total_spent > 100000
ORDER BY region, nation, total_spent DESC;
