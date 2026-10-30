WITH  OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, c.c_nationkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_sales,
        COALESCE(sd.total_supply_cost, 0) AS total_supply_cost
    FROM OrderSummary os
    LEFT JOIN SupplierDetails sd ON os.o_orderkey = sd.s_suppkey
    WHERE os.rank_sales <= 10
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(os.total_sales) AS nation_sales
    FROM Nation n
    JOIN HighValueOrders os ON n.n_nationkey = os.o_orderkey
    GROUP BY n.n_name
)
SELECT 
    ns.n_name,
    ns.nation_sales,
    RANK() OVER (ORDER BY ns.nation_sales DESC) AS sales_rank,
    CASE 
        WHEN ns.nation_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM NationSales ns
ORDER BY ns.nation_sales DESC;