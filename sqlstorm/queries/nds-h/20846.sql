WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(NULLIF(c.c_address, ''), 'Unknown Address') AS address,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM customer c
),
DoubleJoin AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY l.l_partkey
),
CustomerSales AS (
    SELECT 
        ci.c_custkey,
        ci.c_name,
        SUM(ts.total_sales) AS total_customer_sales
    FROM CustomerInfo ci
    JOIN orders o ON ci.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN TotalSales ts ON l.l_partkey = ts.l_partkey
    GROUP BY ci.c_custkey, ci.c_name
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supplier_sales
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE l.l_quantity < 10 
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    COALESCE(cis.total_customer_sales, 0) AS total_customer_sales,
    COALESCE(ss.total_supplier_sales, 0) AS total_supplier_sales,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finalized'
        ELSE 'Processing'
    END AS order_state,
    p.p_name,
    COALESCE(ps.ps_supplycost, 0) * COALESCE(ps.ps_availqty, 0) AS supply_value,
    ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice) AS overall_order_rank
FROM RankedOrders o
LEFT JOIN CustomerSales cis ON o.o_orderkey = cis.c_custkey
LEFT JOIN SupplierSales ss ON ss.total_supplier_sales = (SELECT MAX(total_supplier_sales) FROM SupplierSales)
LEFT JOIN DoubleJoin ps ON o.o_orderkey = ps.p_partkey
JOIN part p ON p.p_partkey = ps.p_partkey
WHERE (o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' OR o.o_orderdate IS NULL)
AND (CAST(o.o_orderstatus AS STRING) LIKE 'P%' OR o.o_orderstatus IS NULL);