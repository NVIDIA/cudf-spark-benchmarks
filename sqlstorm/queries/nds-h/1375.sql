WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        os.net_revenue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    SUM(COALESCE(sd.total_available_qty, 0)) AS total_available_qty,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(COALESCE(co.net_revenue, 0)) AS total_revenue,
    ROUND(AVG(NULLIF(sd.avg_supply_cost, 0)), 2) AS avg_supply_cost
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN 
    customer cust ON s.s_nationkey = cust.c_nationkey
LEFT JOIN 
    CustomerOrders co ON cust.c_custkey = co.c_custkey
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;
