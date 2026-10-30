
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rn,
        p.p_type
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey, EXTRACT(YEAR FROM o.o_orderdate)
), 
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    cs.c_custkey AS cust_key,
    cs.total_revenue AS customer_revenue,
    ss.s_name AS supplier_name,
    ss.s_acctbal AS supplier_balance,
    (CASE 
        WHEN cs.total_revenue IS NULL THEN 'No Revenue' 
        WHEN cs.total_revenue = 0 THEN 'Zero Revenue'
        ELSE (CASE WHEN ss.rn = 1 THEN 'Top Supplier' 
                  ELSE 'Other Supplier' END)
    END) AS supplier_status
FROM 
    CustomerRevenue cs
LEFT JOIN 
    RankedSuppliers ss ON ss.rn <= 3
WHERE 
    (cs.total_revenue IS NOT NULL OR ss.s_acctbal IS NOT NULL)
    AND ss.p_type IN ('TypeA', 'TypeB')
ORDER BY 
    cs.total_revenue DESC, 
    ss.s_acctbal DESC;
