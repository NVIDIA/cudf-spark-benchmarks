WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        s.s_name,
        s.s_nationkey
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
AverageSupplierCosts AS (
    SELECT 
        s_nationkey,
        AVG(ps_supplycost) AS avg_supplycost
    FROM SupplierPartDetails
    GROUP BY s_nationkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        COUNT(l.l_orderkey) AS line_item_count
    FROM RankedOrders ro
    LEFT JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
    WHERE ro.rank_order <= 5
    GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.o_orderstatus
),
FinalResults AS (
    SELECT 
        hvo.o_orderkey,
        hvo.o_orderdate,
        hvo.o_totalprice,
        hvo.o_orderstatus,
        CASE 
            WHEN hvo.o_totalprice > avgc.avg_supplycost THEN 'Above Average'
            ELSE 'Below Average'
        END AS price_comparison
    FROM HighValueOrders hvo
    JOIN AverageSupplierCosts avgc ON hvo.o_orderstatus = 'O'
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    f.o_orderstatus,
    f.price_comparison,
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM FinalResults f
LEFT JOIN supplier s ON f.o_orderstatus = 'O' AND s.s_nationkey IN (
    SELECT 
        n.n_nationkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_comment IS NOT NULL
) 
RIGHT JOIN region r ON r.r_regionkey = 1
GROUP BY 
    f.o_orderkey, 
    f.o_orderdate, 
    f.o_totalprice, 
    f.o_orderstatus, 
    f.price_comparison, 
    r.r_name
ORDER BY 
    f.o_totalprice DESC
LIMIT 10;