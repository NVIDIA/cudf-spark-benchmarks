WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name 
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice,
           SUBSTRING(p.p_comment, 1, 20) AS short_comment
    FROM part p
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name AS customer_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS item_count, MAX(l.l_shipdate) AS last_shipment_date
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    sd.s_name,
    sd.nation_name,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    ld.total_revenue,
    ld.item_count,
    od.o_orderdate,
    od.customer_name,
    pd.short_comment
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    LineItemSummary ld ON ld.l_orderkey = ps.ps_partkey
JOIN 
    OrderDetails od ON od.o_orderkey = ld.l_orderkey
WHERE 
    pd.p_retailprice > 500.00 AND 
    ld.total_revenue > 1000.00
ORDER BY 
    ld.total_revenue DESC, sd.s_name ASC
LIMIT 100;
