WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100 
        AND s.s_acctbal IS NOT NULL
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate <= cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(os.total_revenue) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
), NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(co.total_revenue) AS nation_revenue,
        COUNT(co.order_count) AS customer_count
    FROM 
        nation n
    JOIN 
        customerOrders co ON n.n_nationkey = co.c_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.nation_revenue,
    ns.customer_count,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    RS.s_acctbal AS supplier_account_balance
FROM 
    NationStats ns
LEFT JOIN 
    RankedSuppliers RS ON ns.nation_revenue > 10000 AND RS.rank = 1
WHERE 
    ns.nation_revenue IS NOT NULL
ORDER BY 
    ns.nation_revenue DESC, ns.n_name;