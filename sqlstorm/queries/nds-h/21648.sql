WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) as price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
ExemplaryItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS total_sold,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    HAVING COUNT(DISTINCT l.l_orderkey) > 0
),
FinalSelection AS (
    SELECT 
        e.p_partkey,
        e.p_name,
        e.p_retailprice,
        r.total_cost,
        cs.total_spent,
        ro.price_rank
    FROM ExemplaryItems e
    JOIN SupplierCosts r ON e.p_partkey = r.ps_partkey
    LEFT JOIN CustomerSpending cs ON cs.total_spent = (SELECT MAX(total_spent) FROM CustomerSpending)
    LEFT JOIN RankedOrders ro ON ro.o_orderdate = (SELECT MAX(o_orderdate) FROM orders)
    WHERE e.p_retailprice > r.total_cost * 1.1
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.p_retailprice,
    f.total_cost,
    f.total_spent,
    f.price_rank,
    CASE 
        WHEN f.price_rank IS NULL THEN 'Not Ranked'
        ELSE 'Ranked'
    END AS ranking_status,
    CONCAT('Part ', f.p_name, ' with price: ', f.p_retailprice) AS descriptive_info
FROM FinalSelection f
ORDER BY f.price_rank, f.total_spent DESC
LIMIT 10;
