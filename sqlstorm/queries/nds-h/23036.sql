WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 0
    ORDER BY 
        total_revenue DESC
),
ComplexQuery AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS open_order_total,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        AVG(s.total_supply_cost) AS avg_supply_cost
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        SupplierDetails s ON s.s_suppkey = o.o_custkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL OR COUNT(c.c_custkey) > 0
)
SELECT 
    cq.r_regionkey,
    cq.r_name,
    cq.open_order_total,
    cq.unique_customers,
    cq.avg_supply_cost,
    CASE 
        WHEN cq.avg_supply_cost IS NULL THEN 'No Suppliers'
        WHEN cq.avg_supply_cost > 1000 THEN 'High Supply Cost'
        ELSE 'Normal Supply Cost'
    END AS supply_cost_category,
    (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.order_rank <= 10) AS top_orders_count
FROM 
    ComplexQuery cq
ORDER BY 
    cq.open_order_total DESC, cq.unique_customers ASC;