WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_distribution_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n 
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.avg_account_balance,
    cd.order_count,
    cd.avg_order_value,
    sd.total_distribution_cost,
    CASE 
        WHEN cd.order_count > 0 THEN cd.avg_order_value / cd.order_count 
        ELSE NULL 
    END AS average_value_per_order,
    CASE 
        WHEN sd.rank = 1 THEN 'Top Supplier' 
        ELSE 'Other Supplier' 
    END AS supplier_rank
FROM 
    NationSummary ns
LEFT JOIN 
    SupplierDetails sd ON ns.n_nationkey = sd.s_suppkey
LEFT JOIN 
    CustomerOrders cd ON cd.c_custkey = sd.s_suppkey
WHERE 
    ns.avg_account_balance IS NOT NULL 
    AND (sd.total_distribution_cost IS NULL OR sd.total_distribution_cost < 10000)
ORDER BY 
    ns.n_name ASC, 
    sd.total_distribution_cost DESC NULLS LAST;
