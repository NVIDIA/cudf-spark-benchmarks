WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        COUNT(li.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2 WHERE o2.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    )
    GROUP BY o.o_orderkey, o.o_totalprice
), SupplierCustomerStatistics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0.00) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY c.c_custkey, c.c_name
), CombinedData AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        ss.s_suppkey,
        ss.s_name,
        ccs.c_custkey,
        ccs.c_name,
        ccs.total_spent,
        ccs.order_count,
        hvo.item_count
    FROM RankedSuppliers ss
    CROSS JOIN nation n 
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN SupplierCustomerStatistics ccs ON ss.s_suppkey = ccs.c_custkey
    LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = ccs.c_custkey
    WHERE ss.rn <= 3
    AND (ccs.total_spent IS NOT NULL OR hvo.item_count IS NOT NULL)
)
SELECT 
    region_name, 
    nation_name,
    s_suppkey,
    s_name,
    c_custkey,
    c_name,
    total_spent,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY region_name, nation_name ORDER BY total_spent DESC NULLS LAST) AS total_rank
FROM CombinedData
ORDER BY region_name, nation_name, total_rank;