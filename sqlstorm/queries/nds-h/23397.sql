WITH RecursivePart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        n.n_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL OR s.s_acctbal < 1000 THEN 'Low'
            WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS acctbal_category
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name <> 'USA'
), 
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
), 
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost) IS NOT NULL
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(sd.acctbal_category, 'Unknown') AS supplier_account_balance_category,
    oi.o_orderkey,
    oi.o_orderstatus,
    oi.total_sales,
    oi.unique_customers,
    ps.total_supply_cost,
    CASE 
        WHEN rp.price_rank <= 5 THEN 'Top 5 Parts'
        ELSE 'Other Parts'
    END AS part_category
FROM RecursivePart rp
LEFT JOIN SupplierDetails sd ON rp.p_partkey = sd.s_suppkey
FULL OUTER JOIN OrderInfo oi ON rp.p_partkey = oi.o_orderkey
LEFT JOIN PartSupplier ps ON rp.p_partkey = ps.ps_partkey
WHERE (oi.total_sales > 100000 OR ps.total_supply_cost IS NOT NULL)
    AND (rp.p_retailprice IS NOT NULL OR sd.s_acctbal IS NULL)
ORDER BY rp.p_retailprice DESC NULLS LAST, oi.total_sales DESC;
