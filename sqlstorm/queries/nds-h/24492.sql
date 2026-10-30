WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rank,
        p.p_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        CASE 
            WHEN COUNT(DISTINCT l.l_suppkey) = 0 THEN NULL 
            ELSE COUNT(DISTINCT l.l_suppkey)
        END AS unique_suppliers
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS region_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        SUM(l.l_extendedprice) > 0
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.total_revenue,
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name,
    tr.r_name AS region_name,
    CASE 
        WHEN co.o_totalprice IS NULL THEN 'No Total Price Available'
        ELSE CASE 
            WHEN co.total_revenue > co.o_totalprice THEN 'Profitable'
            ELSE 'Non-Profitable'
        END
    END AS profitability_status
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedSuppliers rs ON co.o_orderkey = rs.s_suppkey
LEFT JOIN 
    TopRegions tr ON tr.region_rank = 1  
WHERE 
    (co.unique_suppliers IS NULL OR co.unique_suppliers > 5)
    AND co.total_revenue IS NOT NULL
ORDER BY 
    co.total_revenue DESC, co.o_orderkey;