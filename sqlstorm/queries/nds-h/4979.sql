WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 50.00
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
)
SELECT 
    sd.s_name,
    sd.nation_name,
    hp.total_supply_value,
    os.total_order_value,
    os.supplier_count,
    CASE 
        WHEN os.total_order_value IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM SupplierDetails sd
LEFT JOIN HighValueParts hp ON sd.s_suppkey = hp.ps_partkey
FULL OUTER JOIN OrderSummary os ON sd.s_suppkey = os.o_orderkey
WHERE sd.rank <= 5
ORDER BY sd.nation_name, hp.total_supply_value DESC NULLS LAST;