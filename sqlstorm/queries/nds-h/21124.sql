
WITH RankedParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_retailprice,
        RANK() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rnk
    FROM part
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(o.order_count, 0) AS order_count,
        COALESCE(o.average_order_value, 0) AS average_order_value
    FROM customer c
    LEFT JOIN CustomerOrders o ON c.c_custkey = o.c_custkey
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal) 
        FROM customer c2 
        WHERE c2.c_mktsegment = 'HOUSEHOLD'
    )
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.s_nationkey,
        ROW_NUMBER() OVER (ORDER BY sd.supplier_value DESC) AS row_num
    FROM SupplierDetails sd
    WHERE sd.supplier_value > (
        SELECT MAX(ps.ps_supplycost * ps.ps_availqty) 
        FROM partsupp ps
    ) - 1000
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    f.c_custkey,
    f.c_name,
    ts.s_suppkey,
    ts.s_name,
    f.order_count,
    f.average_order_value,
    COALESCE(ts.row_num, 0) AS top_supplier_rank,
    CASE 
        WHEN f.order_count > 5 THEN 'Frequent'
        ELSE 'Occasional'
    END AS customer_type
FROM RankedParts r
FULL OUTER JOIN FilteredCustomers f ON f.order_count >= r.rnk
LEFT JOIN TopSuppliers ts ON f.order_count = ts.row_num
WHERE r.p_retailprice IS NOT NULL
  AND f.order_count IS NOT NULL
  AND (r.p_brand LIKE 'B%' OR f.average_order_value IS NULL)
  AND ((f.order_count > 0 AND f.average_order_value < 100) OR f.c_custkey IS NULL)
ORDER BY r.p_partkey, f.c_custkey;
