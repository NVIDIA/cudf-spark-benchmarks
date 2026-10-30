WITH RecursiveCustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
),
SupplierParts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank_supply
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal IS NOT NULL AND
        ps.ps_supplycost > 0
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
OrderSupplierInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COALESCE(SUM(sp.ps_supplycost), 0) AS total_supplier_cost
    FROM 
        orders o
    LEFT JOIN SupplierParts sp ON o.o_orderkey = sp.ps_partkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    cco.c_custkey,
    cco.c_name,
    cco.o_orderkey,
    cco.o_orderdate,
    ar.item_count,
    CASE 
        WHEN ar.item_count > 0 THEN 
            ar.total_revenue / ar.item_count 
        ELSE 
            NULL 
    END AS avg_revenue_per_item,
    osi.total_supplier_cost,
    CASE 
        WHEN osi.total_supplier_cost IS NULL THEN 'No Supplier'
        ELSE 'Supplier Available'
    END AS supplier_status
FROM 
    RecursiveCustomerOrders cco
LEFT JOIN 
    AggregatedLineItems ar ON cco.o_orderkey = ar.l_orderkey
LEFT JOIN 
    OrderSupplierInfo osi ON cco.o_orderkey = osi.o_orderkey
WHERE 
    cco.order_rank = 1
    AND (cco.o_orderdate >= '1995-01-01' OR cco.o_orderdate IS NULL)
ORDER BY 
    cco.c_custkey, cco.o_orderdate DESC;
