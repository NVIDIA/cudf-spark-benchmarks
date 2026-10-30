WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        ss.total_suppliers,
        ss.total_avail_qty,
        ss.avg_account_balance,
        COALESCE(od.total_lineitem_price, 0) AS total_order_value
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    LEFT JOIN 
        OrderDetails od ON n.n_nationkey = od.o_orderkey
)
SELECT 
    ns.n_name,
    ns.region_name,
    ns.total_suppliers,
    ns.total_avail_qty,
    ns.avg_account_balance,
    ns.total_order_value,
    CASE 
        WHEN ns.total_order_value > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS supplier_status,
    CONCAT('Nation ', ns.n_name, ' in region ', ns.region_name, ' has ', 
           ns.total_suppliers, ' suppliers with total availability of ', 
           ns.total_avail_qty, ' units and an average balance of ', 
           ROUND(ns.avg_account_balance, 2), '. Order value is ', 
           ROUND(ns.total_order_value, 2), '.') AS status_message
FROM 
    NationSummary ns
WHERE 
    ns.total_suppliers IS NOT NULL
ORDER BY 
    ns.total_order_value DESC
LIMIT 10;
