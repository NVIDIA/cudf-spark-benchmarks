
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        st.total_avail_qty,
        st.avg_supply_cost,
        st.num_parts,
        ROW_NUMBER() OVER (ORDER BY st.total_avail_qty DESC) AS rank
    FROM 
        SupplierStats st
    JOIN 
        supplier s ON st.s_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 10000
),
PopularParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    ts.s_name,
    ts.total_avail_qty,
    ts.avg_supply_cost,
    pp.total_quantity_sold
FROM 
    TopSuppliers ts
LEFT JOIN 
    PopularParts pp ON pp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
WHERE 
    ts.rank <= 10
ORDER BY 
    pp.total_quantity_sold DESC NULLS LAST, 
    ts.total_avail_qty DESC;
