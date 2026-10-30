
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        o.o_custkey
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.total_supply_cost,
        DENSE_RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM SupplierSummary ss
)

SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    tr.nation_name,
    tr.region_name,
    ts.total_supply_cost,
    l.l_discount,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM RankedOrders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN CustomerRegion tr ON tr.c_custkey = o.o_custkey
INNER JOIN TopSuppliers ts ON ts.s_suppkey = l.l_suppkey
WHERE o.order_rank <= 10 
  AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
  AND (l.l_discount > 0.1 OR ts.total_supply_cost IS NULL)
ORDER BY o.o_orderdate DESC, o.o_totalprice DESC;
