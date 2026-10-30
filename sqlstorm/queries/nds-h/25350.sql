WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice,
           SUBSTRING(p.p_comment FROM 1 FOR 22) AS short_comment
    FROM part p
),
OrdersSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_suppkey) AS supplier_count, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierSales AS (
    SELECT si.nation_name, pd.p_brand, SUM(os.total_sales) AS sales_sum
    FROM SupplierInfo si
    JOIN partsupp ps ON si.s_suppkey = ps.ps_suppkey
    JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
    JOIN OrdersSummary os ON ps.ps_partkey = os.o_orderkey 
    GROUP BY si.nation_name, pd.p_brand
)
SELECT nation_name, p_brand, sales_sum,
       ROW_NUMBER() OVER (PARTITION BY nation_name ORDER BY sales_sum DESC) AS rank
FROM SupplierSales
WHERE sales_sum > 1000
ORDER BY nation_name, rank;
