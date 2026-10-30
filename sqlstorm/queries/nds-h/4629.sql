WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS supplier_region
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
ItemDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 10 AND p.p_retailprice < 100.00
),
OrderLineSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(*) AS line_count
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.order_rank,
    COALESCE(SUM(ls.total_price), 0) AS total_sales,
    COALESCE(SUM(ls.total_quantity), 0) AS total_quantity,
    s.s_name AS top_supplier,
    s.s_acctbal AS supplier_balance
FROM RankedOrders o
LEFT JOIN OrderLineSummary ls ON o.o_orderkey = ls.l_orderkey
LEFT JOIN SupplierDetails s ON s.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN ItemDetails id ON ps.ps_partkey = id.p_partkey
    WHERE ps.ps_availqty > 0
    ORDER BY ps.ps_supplycost ASC
    LIMIT 1
)
WHERE o.order_rank <= 5
GROUP BY o.o_orderkey, o.o_orderdate, o.order_rank, s.s_name, s.s_acctbal
ORDER BY total_sales DESC, o.o_orderdate;