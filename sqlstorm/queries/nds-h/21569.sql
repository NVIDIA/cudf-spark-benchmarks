WITH RankedOrders AS (
    SELECT 
        o_orderkey, 
        o_custkey, 
        o_orderstatus, 
        o_totalprice, 
        o_orderdate, 
        o_orderpriority, 
        o_clerk, 
        o_shippriority, 
        o_comment,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS rn
    FROM orders
),

FilteredCustomers AS (
    SELECT 
        c_custkey, 
        c_name, 
        c_address, 
        c_nationkey, 
        c_phone, 
        c_acctbal, 
        c_mktsegment, 
        c_comment
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'BUILDING')
    AND c_mktsegment IN (SELECT DISTINCT c_mktsegment FROM customer WHERE c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'A%'))
),

SupplierStats AS (
    SELECT 
        s_suppkey,
        s_name,
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s_suppkey, s_name
    HAVING SUM(ps_supplycost * ps_availqty) < 100000
),

OrderLineSummary AS (
    SELECT 
        l_orderkey, 
        SUM(l_extendedprice * (1 - l_discount)) AS net_price
    FROM lineitem
    WHERE l_returnflag = 'N'
    GROUP BY l_orderkey
),

FinalResults AS (
    SELECT 
        fc.c_name,
        fc.c_acctbal,
        ro.o_orderkey,
        ro.o_totalprice,
        ss.s_name,
        ss.total_supply_cost,
        ols.net_price,
        ROW_NUMBER() OVER (PARTITION BY fc.c_name ORDER BY ols.net_price DESC) AS price_rank
    FROM FilteredCustomers fc
    LEFT JOIN RankedOrders ro ON fc.c_custkey = ro.o_custkey AND ro.rn <= 5
    LEFT JOIN SupplierStats ss ON ss.unique_parts > 3
    LEFT JOIN OrderLineSummary ols ON ols.l_orderkey = ro.o_orderkey
    WHERE fc.c_acctbal IS NOT NULL AND ss.total_supply_cost IS NOT NULL
)

SELECT 
    f.c_name, 
    f.c_acctbal, 
    f.o_orderkey, 
    f.o_totalprice, 
    f.s_name, 
    f.total_supply_cost, 
    f.net_price,
    CASE 
        WHEN f.total_supply_cost IS NULL THEN 'No Supplier' 
        ELSE 'Supplier Available' 
    END AS supplier_status,
    CASE 
        WHEN f.price_rank IS NOT NULL AND f.price_rank <= 3 THEN 'Top Tier Order' 
        ELSE 'Other Orders' 
    END AS order_tier
FROM FinalResults f
WHERE f.c_acctbal BETWEEN 1000 AND (SELECT MAX(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL) 
OR f.total_supply_cost < (SELECT AVG(total_supply_cost) FROM SupplierStats)
ORDER BY f.c_name, f.o_orderkey DESC
LIMIT 100;
