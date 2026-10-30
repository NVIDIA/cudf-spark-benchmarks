WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1996-01-01' AND l.l_shipdate <= '1996-12-31'
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    ORDER BY ss.total_sales DESC
    LIMIT 10
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, ss.total_sales
    FROM part p
    JOIN SupplierSales ss ON p.p_partkey = ss.s_suppkey
)
SELECT ts.s_name, pd.p_name, pd.p_brand, pd.p_retailprice, pd.total_sales
FROM TopSuppliers ts
JOIN PartDetails pd ON ts.s_suppkey = pd.total_sales
ORDER BY ts.total_sales DESC, pd.p_retailprice ASC;