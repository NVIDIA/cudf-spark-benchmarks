WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),

SupplierAggregate AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_availqty) > 1000
),

TopSuppliers AS (
    SELECT 
        sa.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY sa.total_supply_cost DESC) AS rank
    FROM SupplierAggregate sa
    JOIN supplier s ON sa.s_suppkey = s.s_suppkey
)

SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o_orderstatus,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    COALESCE(ts.s_acctbal, 0) AS supplier_acctbal
FROM RankedOrders o
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_orderkey) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING COUNT(l.l_orderkey) > 5
) li ON o.o_orderkey = li.l_orderkey
LEFT JOIN TopSuppliers ts ON ts.rank <= 10 AND li.item_count IS NOT NULL
WHERE o.o_orderstatus IN ('O', 'F')
ORDER BY o.o_totalprice DESC, o.o_orderdate;