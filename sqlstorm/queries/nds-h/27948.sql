WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice, 
           SUBSTRING(p.p_comment, 1, 23) AS short_comment
    FROM part p
    WHERE p.p_retailprice > 100.00
),
OrderInfo AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           c.c_name AS customer_name, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FinalReport AS (
    SELECT sd.s_name, sd.nation_name, pd.p_name, ld.total_quantity, ld.avg_price,
           oi.o_orderdate
    FROM SupplierDetails sd
    JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
    JOIN LineItemSummary ld ON ld.l_orderkey = ps.ps_partkey
    JOIN OrderInfo oi ON oi.o_orderkey = ld.l_orderkey
)
SELECT s_name, nation_name, p_name, total_quantity, avg_price, o_orderdate
FROM FinalReport
ORDER BY nation_name, avg_price DESC
LIMIT 50;
