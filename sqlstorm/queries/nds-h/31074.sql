WITH  CTE_Supplier_Sales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
Top_Suppliers AS (
    SELECT s_suppkey, s_name
    FROM CTE_Supplier_Sales
    WHERE sales_rank <= 10
),
Supplier_Details AS (
    SELECT
        ts.s_suppkey,
        ts.s_name,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied,
        MAX(ps.ps_supplycost) AS max_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM Top_Suppliers ts
    JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ts.s_suppkey, ts.s_name
),
Customer_Orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT
    sd.s_name,
    sd.unique_parts_supplied,
    sd.max_supply_cost,
    sd.avg_supply_cost,
    co.c_name,
    co.order_count,
    co.total_spent
FROM Supplier_Details sd
FULL OUTER JOIN Customer_Orders co ON sd.s_suppkey = co.c_custkey
WHERE (sd.unique_parts_supplied IS NOT NULL OR co.order_count IS NOT NULL)
  AND (sd.max_supply_cost > 500 OR co.total_spent < 1000)
ORDER BY sd.avg_supply_cost DESC, co.total_spent DESC;
