
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
NationRegion AS (
    SELECT 
        n.n_name,
        r.r_name,
        COUNT(*) AS country_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Not Finalized'
        END AS status
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
FilteredOrders AS (
    SELECT 
        os.order_year,
        SUM(os.total_revenue) AS yearly_revenue,
        COUNT(DISTINCT os.o_orderkey) AS order_count
    FROM 
        OrderSummary os
    WHERE 
        os.total_revenue > 5000
    GROUP BY 
        os.order_year
)
SELECT 
    np.r_name,
    np.n_name,
    SUM(fp.yearly_revenue) AS total_revenue,
    AVG(fp.order_count) AS avg_orders_per_year,
    COUNT(DISTINCT rp.p_partkey) AS total_parts,
    CASE 
        WHEN COUNT(DISTINCT rp.p_partkey) > 10 THEN 'Diverse Portfolio'
        WHEN COUNT(DISTINCT rp.p_partkey) = 0 THEN 'No Parts Available'
        ELSE 'Limited Selection'
    END AS portfolio_status
FROM 
    NationRegion np
LEFT JOIN 
    RankedParts rp ON np.n_name = rp.p_brand
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = rp.p_partkey
FULL OUTER JOIN 
    FilteredOrders fp ON EXTRACT(YEAR FROM DATE '1998-10-01') = fp.order_year
WHERE 
    np.country_count > 1
GROUP BY 
    np.r_name, np.n_name
HAVING 
    SUM(fp.yearly_revenue) > 10000
ORDER BY 
    total_revenue DESC, avg_orders_per_year DESC
LIMIT 100 OFFSET 10;
