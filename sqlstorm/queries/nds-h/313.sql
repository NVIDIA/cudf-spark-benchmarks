WITH SalesRanking AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY c.c_custkey, c.c_name, n.n_nationkey
), SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT
    sr.c_name,
    sr.total_sales,
    sd.s_name AS supplier_name,
    sd.total_supply_cost,
    (CASE 
        WHEN sr.total_sales > 10000 THEN 'High Value'
        WHEN sr.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS customer_value_category
FROM
    SalesRanking sr
LEFT JOIN SupplierDetails sd ON sr.c_custkey = sd.s_suppkey
WHERE
    (sr.sales_rank <= 5 OR sd.total_supply_cost IS NULL)
ORDER BY
    sr.total_sales DESC, customer_value_category;
